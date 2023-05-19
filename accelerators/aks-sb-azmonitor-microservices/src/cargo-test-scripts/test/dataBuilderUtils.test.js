const expect = require('chai').expect;
const dataBuilderUtil = require('../dataBuilderUtils');
const addDays = require('date-fns/addDays');

describe('Make Invalid Functionality', () => {
    it('Should make the dates occur in the past', () => {
        const cargo = dataBuilderUtil.generateBaseCargoObject();
        //Make sure the values are populated
        dataBuilderUtil.makeInvalid(cargo, false, 1);
        expect(cargo.demandDates.start).to.not.be.undefined;
        expect(cargo.demandDates.end).to.not.be.undefined;
        //Make sure the start date occurs before the end date
        expect(cargo.demandDates.end).to.be.above(cargo.demandDates.start);
        //Make sure the dates occur in the past
        expect(new Date()).to.be.above(cargo.demandDates.end);
    });

    it('Should make the dates occur to far in the future', () => {
        const cargo = dataBuilderUtil.generateBaseCargoObject();
        dataBuilderUtil.makeInvalid(cargo, false, 2);
        //Make sure the values are populated
        expect(cargo.demandDates.start).to.not.be.undefined;
        expect(cargo.demandDates.end).to.not.be.undefined;
        //Make sure the start date occurs before the end date
        expect(cargo.demandDates.end).to.be.above(cargo.demandDates.start);
        //Make sure the dates occur to far into the future
        expect(addDays(new Date(), 60)).to.be.below(cargo.demandDates.start);
    });

    it('Should make the dates to far apart', () => {
        const cargo = dataBuilderUtil.generateBaseCargoObject();
        dataBuilderUtil.makeInvalid(cargo, false, 3);
        //Make sure the values are populated
        expect(cargo.demandDates.start).to.not.be.undefined;
        expect(cargo.demandDates.end).to.not.be.undefined;
        //Make sure the start date occurs before the end date
        expect(cargo.demandDates.end).to.be.above(cargo.demandDates.start);
        //Make sure the dates occur to far apart
        expect(cargo.demandDates.end - cargo.demandDates.start).to.be.above(30);
    });

    it('Should make the end date occur before the start date', () => {
        const cargo = dataBuilderUtil.generateBaseCargoObject();
        dataBuilderUtil.makeInvalid(cargo, false, 4);
        //Make sure the values are populated
        expect(cargo.demandDates.start).to.not.be.undefined;
        expect(cargo.demandDates.end).to.not.be.undefined;
        //Make sure the start date occurs after the end date
        expect(cargo.demandDates.end).to.be.below(cargo.demandDates.start);
    });

    it('Should populate the error details on the cargo object', () => {
        const cargo = dataBuilderUtil.generateBaseCargoObject();
        dataBuilderUtil.makeInvalid(cargo, true, 1);
        //Make sure the values are populated
        expect(cargo.valid).to.be.false;
        expect(cargo.errorMessage).to.not.be.undefined;
    });
});

